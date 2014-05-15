module Gitlab
  class Seeder
    def self.quiet
      mute_mailer
      SeedFu.quiet = true
      yield
      SeedFu.quiet = false
      puts "\nOK".green
    end

    def self.by_user(user)
      begin
        Thread.current[:current_user] = user
        yield
      ensure
        Thread.current[:current_user] = nil
      end
    end

    def self.mute_mailer
      code = <<-eos
def Notify.delay
  self
end
      eos
      eval(code)
    end
  end
end
