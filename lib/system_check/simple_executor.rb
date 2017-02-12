module SystemCheck
  class SimpleExecutor < BaseExecutor
    def execute
      start_checking(component)

      @checks.each do |check|
        print "#{check.name}"
        if check.skip?
          puts "skipped #{'('+skip_message+')' if skip_message}".color(:magenta)
        elsif check.check?
          puts 'yes'.color(:green)
        else
          puts 'no'.color(:red)
          check.show_error
        end
      end

      finished_checking(component)
    end

    private

    def start_checking(component)
      puts "Checking #{component.color(:yellow)} ..."
      puts ''
    end

    def finished_checking(component)
      puts ''
      puts "Checking #{component.color(:yellow)} ... #{"Finished".color(:green)}"
      puts ''
    end
  end
end
