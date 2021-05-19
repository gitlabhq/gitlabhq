# frozen_string_literal: true

if Gitlab::Utils.to_boolean(ENV['STACKPROF_ENABLED'].to_s)
  Gitlab::StackProf.install
end
