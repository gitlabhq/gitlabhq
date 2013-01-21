module Gitlab
  class Seeder
    def self.quiet
      SeedFu.quiet = true
      yield
      SeedFu.quiet = false
      puts "\nOK".green
    end
  end
end
