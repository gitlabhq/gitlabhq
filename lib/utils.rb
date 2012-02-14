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
      case file_name
      when /(\.pl|\.scala|\.java|\.haml|\.jade|\.scaml|\.html|\.sass|\.scss|\.php|\.erb)$/
        $1[1..-1].to_sym
      when /(\.c|\.h|\.idc)$/
        :c
      when /(\.cpp|\.hpp|\.c++|\.h++|\.cc|\.hh|\.cxx|\.hxx)$/
        :cpp
      when /(\.d|\.di)$/
        :d
      when /(\.hs|\.lhs)$/
        :haskell
      when /(\.rb|\.ru|\.rake|Rakefile|\.gemspec|\.rbx|Gemfile)$/
        :ruby
      when /(\.py|\.pyw|\.sc|SConstruct|SConscript|\.tac)$/
        :python
      when /(\.js|\.json)$/
        :javascript
      when /(\.xml|\.xsl|\.rss|\.xslt|\.xsd|\.wsdl)$/
        :xml
      when /(\.vm|\.fhtml)$/
        :velocity
      when /\.sh$/
        :bash
      when /\.coffee$/
        :coffeescript
      when /(\.yml|\.yaml)$/
        :yaml
      when /\.md$/
        :minid
      else
        :text
      end
    end
  end
end
