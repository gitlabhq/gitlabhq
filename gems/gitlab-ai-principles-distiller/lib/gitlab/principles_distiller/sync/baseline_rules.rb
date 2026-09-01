# frozen_string_literal: true

module Gitlab
  module PrinciplesDistiller
    class Sync
      module BaselineRules
        extend self

        THEMATIC_BREAK = /\A(?:-{3,}|\*{3,}|_{3,})\z/

        CHECKLIST_HEADING = /^##\s+Checklist\s*$/
        SOURCES_HEADING = /^##\s+Authoritative sources\s*$/
        LIST_MARKER = /\A(?:[-*+]|\d+[.)])\s/

        # Exclude preamble the prompt forbids the agent from emitting.
        def baseline_rules(baseline)
          heading = baseline.index(CHECKLIST_HEADING)
          heading ? baseline[heading..] : baseline
        end

        # Exclude the footer so listed paths do not count as duplicate rules.
        def checklist_body(content)
          content.split(SOURCES_HEADING, 2).first.to_s
        end

        # Ignore formatting differences while preserving semantic changes.
        def logical_units(text)
          units = []
          current = nil

          text.each_line do |raw|
            line = raw.strip

            if unit_boundary?(line)
              units << current if current
              current = nil
            elsif current.nil? || line.match?(LIST_MARKER)
              units << current if current
              current = line
            else
              current = "#{current} #{line}"
            end
          end

          units << current if current
          units.map { |unit| normalize_unit(unit) }
        end

        # Maps each normalized unit to every heading it appears under, so a caller can tell a single
        # correctly-placed rule from one that also appears elsewhere.
        def units_by_section(text)
          sections = {}
          section = nil
          current = nil

          record = ->(unit) do
            return unless unit

            (sections[normalize_unit(unit)] ||= []) << section
          end

          text.each_line do |raw|
            line = raw.strip

            if line.start_with?('#')
              record.call(current)
              current = nil
              section = line
            elsif line.empty? || line.match?(THEMATIC_BREAK)
              record.call(current)
              current = nil
            elsif current.nil? || line.match?(LIST_MARKER)
              record.call(current)
              current = line
            else
              current = "#{current} #{line}"
            end
          end

          record.call(current)
          sections
        end

        private

        def unit_boundary?(line)
          line.empty? || line.start_with?('#') || line.match?(THEMATIC_BREAK)
        end

        def normalize_unit(unit)
          unit.sub(/\A(?:[-*+]|\d+[.)])\s+/, '').gsub(/\s+/, ' ').delete_suffix('.')
        end
      end
    end
  end
end
