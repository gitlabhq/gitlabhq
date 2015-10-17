module ExceptionsHelper
  def pretty_hash(hash, nesting = 0)
    tab_size = 2
    nesting += 1

    pretty  = "{"
    sorted_keys = hash.keys.sort
    sorted_keys.each do |key|
      val = hash[key].is_a?(Hash) ? pretty_hash(hash[key], nesting) : hash[key].inspect
      pretty += "\n#{' '*nesting*tab_size}"
      pretty += "#{key.inspect} => #{val}"
      pretty += "," unless key == sorted_keys.last

    end
    nesting -= 1
    pretty += "\n#{' '*nesting*tab_size}}"
  end

  # for formatting the backtraces on the exception show page
  def format_backtrace(backtrace)
    raw backtrace.file + ":<b>" + "#{backtrace.line}" + "</b> " + "'" + backtrace.method + "'"
  end

  # Group lines into sections of in-app files and external files
  # (An implementation of Enumerable#chunk so we don't break 1.8.7 support.)
  def grouped_lines(lines)
    line_groups = []
    lines.each do |line|
      in_app = line.in_app?
      if line_groups.last && line_groups.last[0] == in_app
        line_groups.last[1] << line
      else
        line_groups << [in_app, [line]]
      end
    end
    line_groups
  end
end