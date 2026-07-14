# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Rules
        class Rule
          class Clause
            # Shared, ReDoS-guarded matcher for rules:changes:regexp and
            # rules:exists:regexp. Owns the safety invariants (expanded-length cap,
            # comparison limit, per-match timeout, total time budget). Every guard logs;
            # all raise a ParseError (user misconfiguration) except the comparison limit,
            # which fails open (too many files is not a user error). Callers own path
            # sourcing and result caching.
            class RegexpMatcher
              # Stripped from patterns before logging so control characters in
              # user input cannot inject newlines or escape sequences into logs.
              CONTROL_CHARS_PATTERN = /[[:cntrl:]]/

              def initialize(raw_pattern:, expanded_pattern:, max_comparisons:, log_scope:, project_id:)
                @raw_pattern = raw_pattern
                @expanded_pattern = expanded_pattern
                @max_comparisons = max_comparisons
                @log_scope = log_scope
                @project_id = project_id
              end

              attr_reader :expanded_pattern

              def validate_pattern_length!
                return unless @expanded_pattern.length > REGEXP_MAX_LENGTH

                raise ParseError,
                  "#{@log_scope}:regexp is too long " \
                    "(maximum is #{REGEXP_MAX_LENGTH} characters after variable expansion)"
              end

              def match?(paths)
                if paths.size > @max_comparisons
                  # Mirrors the glob CHANGES_MAX_PATTERN_COMPARISONS guard: too many files is
                  # not a user error, so we fail open (assume a match) rather than raise.
                  log(:info, 'regexp comparisons limit exceeded', paths_size: paths.size, regexp: sanitized_pattern)
                  return true
                end

                pattern = Regexp.new(@expanded_pattern, timeout: REGEXP_TIMEOUT_SECONDS)
                deadline = current_monotonic_time + REGEXP_TOTAL_TIMEOUT_SECONDS

                paths.any? do |path|
                  if current_monotonic_time > deadline
                    # A regexp slow enough to exhaust the budget is unusable, so surface it
                    # as a config error rather than silently running the job.
                    log(:warn, 'regexp total time budget exceeded', regexp: sanitized_pattern)
                    raise ParseError, "#{@log_scope}:regexp exceeded the time budget " \
                      "(#{REGEXP_TOTAL_TIMEOUT_SECONDS}s) while evaluating paths"
                  end

                  pattern.match?(path)
                rescue Regexp::TimeoutError
                  log(:warn, 'regexp match timed out', regexp: sanitized_pattern)
                  raise ParseError, "#{@log_scope}:regexp timed out " \
                    "(over #{REGEXP_TIMEOUT_SECONDS}s on a single path)"
                end
              end

              private

              def current_monotonic_time
                Gitlab::Metrics::System.monotonic_time
              end

              def sanitized_pattern
                @raw_pattern.to_s.gsub(CONTROL_CHARS_PATTERN, '')
              end

              def log(severity, message, **extra)
                entry = {
                  class_name: self.class.name,
                  message: "#{@log_scope} #{message}",
                  project_id: @project_id,
                  extra: extra
                }

                severity == :warn ? Gitlab::AppJsonLogger.warn(entry) : Gitlab::AppJsonLogger.info(entry)
              end
            end
          end
        end
      end
    end
  end
end
