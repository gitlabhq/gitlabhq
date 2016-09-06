module SidekiqHelper
  SIDEKIQ_PS_REGEXP = /\A([^\s]+)\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)\s+(.+)\s+(sidekiq.*\])\s+\z/

  def parse_sidekiq_ps(line)
    match = line.match(SIDEKIQ_PS_REGEXP)
    if match
      match[1..6]
    else
      %w{? ? ? ? ? ?}
    end
  end
end
