module SystemCheck
  module Geo
    class ClocksSynchronizationCheck < SystemCheck::BaseCheck
      set_name 'Machine clock is synchronized'

      def check?
        Net::NTP.get.offset.abs < Gitlab::Geo::JwtRequestDecoder::IAT_LEEWAY
      end

      def show_error
        try_fixing_it(
          'Enable a NTP service on this machine to keep clocks synchronized'
        )
      end
    end
  end
end
