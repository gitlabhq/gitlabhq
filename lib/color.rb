module Color
  def colorize(text, color_code)
    "\033[#{color_code}#{text}\033[0m"
  end

  def red(text)
    colorize(text, "31m")
  end

  def green(text)
    colorize(text, "32m")
  end

  def yellow(text)
    colorize(text, "93m")
  end

  def command(string)
    `#{string}`
    if $?.to_i > 0
      puts red " == #{string} - FAIL"
      puts red " == Error during configure"
      exit
    else
      puts green " == #{string} - OK"
    end
  end
end

