module Peek
  module Rblineprof
    module CustomControllerHelpers
      extend ActiveSupport::Concern

      # This will become useless once https://github.com/peek/peek-rblineprof/pull/5
      # is merged
      def pygmentize(file_name, code, lexer = nil)
        if lexer.present?
          Gitlab::Highlight.highlight(file_name, code)
        else
          "<pre>#{Rack::Utils.escape_html(code)}</pre>"
        end
      end

      # rubocop:disable all
      def inject_rblineprof
        ret = nil
        profile = lineprof(rblineprof_profiler_regex) do
          ret = yield
        end

        if response.content_type =~ %r|text/html|
          sort = params[:lineprofiler_sort]
          mode = params[:lineprofiler_mode] || 'cpu'
          min  = (params[:lineprofiler_min] || 5).to_i * 1000
          summary = params[:lineprofiler_summary]

          # Sort each file by the longest calculated time
          per_file = profile.map do |file, lines|
            total, child, excl, total_cpu, child_cpu, excl_cpu = lines[0]

            wall = summary == 'exclusive' ? excl : total
            cpu  = summary == 'exclusive' ? excl_cpu : total_cpu
            idle = summary == 'exclusive' ? (excl - excl_cpu) : (total - total_cpu)

            [
              file, lines,
              wall, cpu, idle,
              sort == 'idle' ? idle : sort == 'cpu' ? cpu : wall
            ]
          end.sort_by{ |a,b,c,d,e,f| -f }

          output = "<div class='modal-dialog modal-full'><div class='modal-content'>"
          output << "<div class='modal-header'>"
          output << "<button class='close btn btn-link btn-sm' type='button' data-dismiss='modal'>X</button>"
          output << "<h4>Line profiling: #{human_description(params[:lineprofiler])}</h4>"
          output << "</div>"
          output << "<div class='modal-body'>"

          per_file.each do |file_name, lines, file_wall, file_cpu, file_idle, file_sort|
            output << "<div class='peek-rblineprof-file'><div class='heading'>"

            show_src = file_sort > min
            tmpl = show_src ? "<a href='#' class='js-lineprof-file'>%s</a>" : "%s"

            if mode == 'cpu'
              output << sprintf("<span class='duration'>% 8.1fms + % 8.1fms</span> #{tmpl}", file_cpu / 1000.0, file_idle / 1000.0, file_name.sub(Rails.root.to_s + '/', ''))
            else
              output << sprintf("<span class='duration'>% 8.1fms</span> #{tmpl}", file_wall/1000.0, file_name.sub(Rails.root.to_s + '/', ''))
            end

            output << "</div>" # .heading

            next unless show_src

            output << "<div class='data'>"
            code = []
            times = []
            File.readlines(file_name).each_with_index do |line, i|
              code << line
              wall, cpu, calls = lines[i + 1]

              if calls && calls > 0
                if mode == 'cpu'
                  idle = wall - cpu
                  times << sprintf("% 8.1fms + % 8.1fms (% 5d)", cpu / 1000.0, idle / 1000.0, calls)
                else
                  times << sprintf("% 8.1fms (% 5d)", wall / 1000.0, calls)
                end
              else
                times << ' '
              end
            end
            output << "<pre class='duration'>#{times.join("\n")}</pre>"
            # The following line was changed from
            # https://github.com/peek/peek-rblineprof/blob/8d3b7a283a27de2f40abda45974516693d882258/lib/peek/rblineprof/controller_helpers.rb#L125
            # This will become useless once https://github.com/peek/peek-rblineprof/pull/16
            # is merged and is implemented.
            output << "<pre class='code highlight white'>#{pygmentize(file_name, code.join, 'ruby')}</pre>"
            output << "</div></div>" # .data then .peek-rblineprof-file
          end

          output << "</div></div></div>"

          response.body += "<div class='modal' id='modal-peek-line-profile' tabindex=-1>#{output}</div>".html_safe
        end

        ret
      end

      private

      def human_description(lineprofiler_param)
        case lineprofiler_param
        when 'app'
          'app/ & lib/'
        when 'views'
          'app/view/'
        when 'gems'
          'vendor/gems'
        when 'all'
          'everything in Rails.root'
        when 'stdlib'
          'everything in the Ruby standard library'
        else
          'app/, config/, lib/, vendor/ & plugin/'
        end
      end
    end
  end
end
