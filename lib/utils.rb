module Utils
  module FileHelper
    def binary?(string) 
      string.each_byte do |x|
        x.nonzero? or return true 
      end
      false
    end

    def image?
      mime_type =~ /image/
    end

    def text?
      mime_type =~ /application|text/ && !binary?(data)
    end
  end

  module Colorize
    def colorize
      system_colorize(data, name)
    end

    def system_colorize(data, file_name)
      ft = handle_file_type(file_name)
      Pygments.highlight(data, :lexer => ft, :options => { :encoding => 'utf-8', :linenos => 'True' })
    end

    def handle_file_type(file_name, mime_type = nil)
      if file_name =~ /(\.rb|\.ru|\.rake|Rakefile|\.gemspec|\.rbx|Gemfile)$/
        :ruby
      elsif file_name =~ /\.py$/
        :python
      elsif file_name =~ /(\.pl|\.scala|\.c|\.cpp|\.java|\.haml|\.html|\.sass|\.scss|\.xml|\.php|\.erb)$/
        $1[1..-1].to_sym
      elsif file_name =~ /\.js$/
        :javascript
      elsif file_name =~ /\.sh$/
        :bash
      elsif file_name =~ /\.coffee$/
        :coffeescript
      elsif file_name =~ /\.yml$/
        :yaml
      elsif file_name =~ /\.md$/
        :minid
      else
        :text
      end
    end
  end
end
