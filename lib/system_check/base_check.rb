module SystemCheck
  class BaseCheck
    def check?
      raise NotImplementedError
    end

    def show_error
      raise NotImplementedError
    end

    def skip?
      false
    end

    def skip_message
    end

    protected

    def try_fixing_it(*steps)
      steps = steps.shift if steps.first.is_a?(Array)

      puts '  Try fixing it:'.color(:blue)
      steps.each do |step|
        puts "  #{step}"
      end
    end

    def fix_and_rerun
      puts '  Please fix the error above and rerun the checks.'.color(:red)
    end

    def for_more_information(*sources)
      sources = sources.shift if sources.first.is_a?(Array)

      puts '  For more information see:'.color(:blue)
      sources.each do |source|
        puts '  #{source}'
      end
    end
  end
end
