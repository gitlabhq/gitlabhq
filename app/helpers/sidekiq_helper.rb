module SidekiqHelper
  SIDEKIQ_PS_REGEXP = /\A
    (?<pid>\d+)\s+
    (?<cpu>[\d\.,]+)\s+
    (?<mem>[\d\.,]+)\s+
    (?<state>[DRSTWXZNLsl\+<]+)\s+
    (?<start>.+)\s+
    (?<command>sidekiq.*\])\s*
    \z/x

  def parse_sidekiq_ps(line)
    match = line.match(SIDEKIQ_PS_REGEXP)
    if match
      match[1..6]
    else
      %w[? ? ? ? ? ?]
    end
  end
end
