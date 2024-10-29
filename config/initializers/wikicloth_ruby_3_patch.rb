# This file contains code based on the wikicloth project:
# https://github.com/nricciar/wikicloth
#
# Copyright (c) 2009 The wikicloth authors.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# frozen_string_literal: true

require 'wikicloth'
require 'wikicloth/wiki_buffer/var'

# Adds patch for changes in this PRs:
#
# https://github.com/nricciar/wikicloth/pull/110
#
# The maintainers are not releasing new versions, so we
# need to patch it here.
#
# If they ever do release a version, then we can remove this file.
#
# See:
# - https://gitlab.com/gitlab-org/gitlab/-/issues/372400

# Guard to ensure we remember to delete this patch if they ever release a new version of wikicloth
unless Gem::Version.new(WikiCloth::VERSION) == Gem::Version.new('0.8.1')
  raise 'New version of WikiCloth detected, please either update the version for this check, ' \
    'or remove this patch if no longer needed'
end

# rubocop:disable Style/ClassAndModuleChildren
# rubocop:disable Style/HashSyntax
# rubocop:disable Layout/SpaceAfterComma
# rubocop:disable Style/RescueStandardError
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/PerceivedComplexity
# rubocop:disable Cop/LineBreakAroundConditionalBlock
# rubocop:disable Layout/EmptyLineAfterGuardClause
# rubocop:disable Performance/ReverseEach
# rubocop:disable Style/PerlBackrefs
# rubocop:disable Performance/StringInclude
# rubocop:disable Style/IfUnlessModifier
# rubocop:disable Layout/LineLength
# rubocop:disable Lint/UselessAssignment
# rubocop:disable Lint/RedundantStringCoercion
# rubocop:disable Style/StringLiteralsInInterpolation
# rubocop:disable Style/For
# rubocop:disable Style/SlicingWithRange
# rubocop:disable Cop/LineBreakAfterGuardClauses
# rubocop:disable Layout/MultilineHashBraceLayout
module WikiCloth
  class WikiCloth
    class MathExtension < Extension
      # <math>latex markup</math>
      #
      element 'math', :skip_html => true, :run_globals => false do |buffer|
        blahtex_path = @options[:blahtex_path] || '/usr/bin/blahtex'
        blahtex_png_path = @options[:blahtex_png_path] || '/tmp'
        blahtex_options = @options[:blahtex_options] || '--texvc-compatible-commands --mathml-version-1-fonts --disallow-plane-1 --spacing strict'

        if File.exist?(blahtex_path) && @options[:math_formatter] != :google
          begin
            # pass tex markup to blahtex
            response = IO.popen("#{blahtex_path} #{blahtex_options} --png --mathml --png-directory #{blahtex_png_path}","w+") do |pipe|
              pipe.write(buffer.element_content)
              pipe.close_write
              pipe.gets
            end

            xml_response = REXML::Document.new(response).root

            if @options[:blahtex_html_prefix]
              # render as embedded image
              file_md5 = xml_response.elements["png/md5"].text
              "<img src=\"#{File.join(@options[:blahtex_html_prefix],"#{file_md5}.png")}\" />"
            else
              # render as mathml
              html = xml_response.elements["mathml/markup"].text
              "<math xmlns=\"http://www.w3.org/1998/Math/MathML\">#{xml_response.elements["mathml/markup"].children.to_s}</math>"
            end
          rescue => err
            # blahtex error
            "<span class=\"error\">#{I18n.t("unable to parse mathml", :error => err)}</span>"
          end
        else
          # if blahtex does not exist fallback to google charts api
          # This is the patched line from:
          # https://github.com/nricciar/wikicloth/pull/110/files#diff-f0cb4c400957bbdcc4c97d69d2aa7f48d8ba56c5943e484863f620605d7d17d4R37
          encoded_string = URI.encode_www_form_component(buffer.element_content)
          "<img src=\"https://chart.googleapis.com/chart?cht=tx&chl=#{encoded_string}\" />"
        end
      end
    end

    class WikiBuffer::Var < WikiBuffer
      def default_functions(name,params)
        case name
        when "#if"
          params.first.blank? ? params[2] : params[1]
        when "#switch"
          match = params.first
          default = nil
          for p in params[1..-1]
            temp = p.split("=")
            if p !~ /=/ && temp.length == 1 && p == params.last
              return p
            elsif temp.instance_of?(Array) && !temp.empty?
              test = temp.first.strip
              default = temp[1..-1].join("=").strip if test == "#default"
              return temp[1..-1].join("=").strip if test == match || (test == "none" && match.blank?)
            end
          end
          default.nil? ? "" : default
        when "#expr"
          begin
            ExpressionParser::Parser.new.parse(params.first)
          rescue RuntimeError
            I18n.t('expression error', :error => $!)
          end
        when "#ifexpr"
          val = false
          begin
            val = ExpressionParser::Parser.new.parse(params.first)
          rescue RuntimeError
          end
          if val
            params[1]
          else
            params[2]
          end
        when "#ifeq"
          if params[0] =~ /^[0-9A-Fa-f]+$/ && params[1] =~ /^[0-9A-Fa-f]+$/
            params[0].to_i == params[1].to_i ? params[2] : params[3]
          else
            params[0] == params[1] ? params[2] : params[3]
          end
        when "#len"
          params.first.length
        when "#sub"
          params.first[params[1].to_i,params[2].to_i]
        when "#pad"
          case params[3]
          when "right"
            params[0].ljust(params[1].to_i,params[2])
          when "center"
            params[0].center(params[1].to_i,params[2])
          else
            params[0].rjust(params[1].to_i,params[2])
          end
        when "#iferror"
          params.first =~ /error/ ? params[1] : params[2]
        when "#capture"
          @options[:params][params.first] = params[1]
          ""
        when "urlencode"
          # This is the patched line from:
          # https://github.com/nricciar/wikicloth/pull/110/files#diff-f262faf4fadb222cca87185be0fb65b3f49659abc840794cc83a736d41310fb1R170
          URI.encode_www_form_component(params.first)
        when "lc"
          params.first.downcase
        when "uc"
          params.first.upcase
        when "ucfirst"
          params.first.capitalize
        when "lcfirst"
          params.first[0,1].downcase + params.first[1..-1]
        when "anchorencode"
          params.first.gsub(/\s+/,'_')
        when "plural"
          begin
            expr_value = ExpressionParser::Parser.new.parse(params.first)
            expr_value.to_i == 1 ? params[1] : params[2]
          rescue RuntimeError
            I18n.t('expression error', :error => $!)
          end
        when "ns"
          values = {
            "" => "", "0" => "",
            "1" => localise_ns("Talk"), "talk" => localise_ns("Talk"),
            "6" => localise_ns("File"), "file" => localise_ns("File"), "image" => localise_ns("File"),
            "10" => localise_ns("Template"), "template" => localise_ns("Template"),
            "14" => localise_ns("Category"), "category" => localise_ns("Category"),
            "-1" => localise_ns("Special"), "special" => localise_ns("Special"),
            "12" => localise_ns("Help"), "help" => localise_ns("Help"),
            "-2" => localise_ns("Media"), "media" => localise_ns("Media") }

          values[localise_ns(params.first,:en).gsub(/\s+/,'_').downcase]
        when "#language"
          WikiNamespaces.language_name(params.first)
        when "#tag"
          return "" if params.empty?
          elem = Builder::XmlMarkup.new
          return elem.tag!(params.first) if params.length == 1
          return elem.tag!(params.first) { |e| e << params.last } if params.length == 2
          tag_attrs = {}
          params[1..-2].each do |attr|
            tag_attrs[$1] = $2 if attr =~ /^\s*([\w]+)\s*=\s*"(.*)"\s*$/
          end
          elem.tag!(params.first,tag_attrs) { |e| e << params.last }
        when "debug"
          ret = nil
          case params.first
          when "param"
            @options[:buffer].buffers.reverse.each do |b|
              if b.instance_of?(WikiBuffer::HTMLElement) && b.element_name == "template"
                ret = b.get_param(params[1])
              end
            end
            ret
          when "buffer"
            ret = "<pre>"
            buffer = @options[:buffer].buffers
            buffer.each do |b|
              ret += " --- #{b.class}"
              ret += b.instance_of?(WikiBuffer::HTMLElement) ? " -- #{b.element_name}\n" : " -- #{b.data}\n"
            end
            "#{ret}</pre>"
          end
        end
      end
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
# rubocop:enable Style/HashSyntax
# rubocop:enable Layout/SpaceAfterComma
# rubocop:enable Style/RescueStandardError
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/PerceivedComplexity
# rubocop:enable Cop/LineBreakAroundConditionalBlock
# rubocop:enable Layout/EmptyLineAfterGuardClause
# rubocop:enable Performance/ReverseEach
# rubocop:enable Style/PerlBackrefs
# rubocop:enable Performance/StringInclude
# rubocop:enable Style/IfUnlessModifier
# rubocop:enable Layout/LineLength
# rubocop:enable Lint/UselessAssignment
# rubocop:enable Lint/RedundantStringCoercion
# rubocop:enable Style/StringLiteralsInInterpolation
# rubocop:enable Style/For
# rubocop:enable Style/SlicingWithRange
# rubocop:enable Cop/LineBreakAfterGuardClauses
# rubocop:enable Layout/MultilineHashBraceLayout
