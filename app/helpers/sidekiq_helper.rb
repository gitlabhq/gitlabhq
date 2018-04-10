module SidekiqHelper
  SIDEKIQ_PS_REGEXP = %r{\A
    (?<pid>\d+)\s+
    (?<cpu>[\d\.,]+)\s+
    (?<mem>[\d\.,]+)\s+
    (?<state>[DIEKNRSTVWXZNLpsl\+<>/\d]+)\s+
    (?<start>.+?)\s+
    (?<command>(?:ruby\d+:\s+)?sidekiq.*\].*)
    \z}x

  def parse_sidekiq_ps(line)
    match = line.strip.match(SIDEKIQ_PS_REGEXP)
    match ? match[1..6] : Array.new(6, '?')
  end
end
