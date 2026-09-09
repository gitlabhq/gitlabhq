# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::PolicyStore::RuleTranspiler::AuthoredInstant do
  def authored_instant(raw_value, field: "starts_at", window_name: "eoq", rule_index: 0)
    transpiler = Gitlab::PolicyStore::RuleTranspiler.new({}, rule_index: rule_index)
    described_class.new(raw_value, field: field, window_name: window_name,
      invalid: transpiler.method(:invalid!), reported_value: transpiler.method(:reported_value))
  end

  describe "#normalized" do
    it "accepts an offset written without a colon" do
      expect(authored_instant("2026-09-01T12:00:00+0200").normalized).to eq("2026-09-01T10:00:00Z")
    end

    it "accepts a lowercase zone designator, which the parser reads and the emitter normalizes" do
      expect(authored_instant("2026-12-24T00:00:00z").normalized).to eq("2026-12-24T00:00:00Z")
    end

    it "accepts a lowercase date separator, which RFC 3339 permits" do
      expect(authored_instant("2026-12-24t00:00:00Z").normalized).to eq("2026-12-24T00:00:00Z")
    end

    it "accepts a leap day in a leap year, which the date check must not read as non-existent" do
      expect(authored_instant("2028-02-29T00:00:00Z").normalized).to eq("2028-02-29T00:00:00Z")
    end

    it "accepts a zero fraction, which drops without changing the instant" do
      expect(authored_instant("2026-12-24T00:00:00.000Z").normalized).to eq("2026-12-24T00:00:00Z")
    end

    it "does not compile a bound whose meaning depends on the host time zone" do
      expect { authored_instant("2026-09-01T00:00:00").normalized }
        .to raise_error(Gitlab::PolicyStore::ValidationError, /starts_at must be an RFC 3339 instant/)
    end

    it "names the shape, not the calendar, when a two-digit year would parse leniently" do
      expect { authored_instant("26-12-24T00:00:00Z").normalized }
        .to raise_error(Gitlab::PolicyStore::ValidationError,
          'rule 0: calendar window "eoq" starts_at must be an RFC 3339 instant such as ' \
            '`2026-12-24T00:00:00Z`: "26-12-24T00:00:00Z"')
    end

    it "rejects a five-digit year, which is not the shape an instant takes" do
      expect { authored_instant("10000-01-01T00:00:00Z").normalized }
        .to raise_error(Gitlab::PolicyStore::ValidationError,
          'rule 0: calendar window "eoq" starts_at must be an RFC 3339 instant such as ' \
            '`2026-12-24T00:00:00Z`: "10000-01-01T00:00:00Z"')
    end

    it "rejects an instant whose UTC form the string comparison cannot order" do
      expect { authored_instant("9999-12-31T23:00:00-05:00").normalized }
        .to raise_error(Gitlab::PolicyStore::ValidationError,
          'rule 0: calendar window "eoq" starts_at is outside the range the emitted comparison can order: ' \
            '"9999-12-31T23:00:00-05:00"')
    end

    it "rejects a bound finer than the second the comparison comes down to" do
      expect { authored_instant("2027-01-02T23:59:59.999Z", field: "ends_at").normalized }
        .to raise_error(Gitlab::PolicyStore::ValidationError,
          'rule 0: calendar window "eoq" ends_at carries sub-second precision the emitted comparison ' \
            'cannot represent: "2027-01-02T23:59:59.999Z"')
    end

    it "rejects a bound too long to be an instant before parsing it, since the parse is the cost" do
      too_long = "#{'9' * 1_000_000}-01-01T00:00:00Z"

      expect { authored_instant(too_long).normalized }
        .to raise_error(Gitlab::PolicyStore::ValidationError,
          "rule 0: calendar window \"eoq\" starts_at is longer than any instant: " \
            "#{('9' * 64).inspect} (#{too_long.length} characters)")
    end

    it "rejects a date that does not exist, rather than rolling it into the next month" do
      expect { authored_instant("2026-06-31T10:00:00Z").normalized }
        .to raise_error(Gitlab::PolicyStore::ValidationError,
          'rule 0: calendar window "eoq" starts_at names a date or time that does not exist: ' \
            '"2026-06-31T10:00:00Z"')
    end

    it "rejects a leap day in a non-leap year" do
      expect { authored_instant("2027-02-29T00:00:00Z").normalized }
        .to raise_error(Gitlab::PolicyStore::ValidationError,
          'rule 0: calendar window "eoq" starts_at names a date or time that does not exist: ' \
            '"2027-02-29T00:00:00Z"')
    end

    it "rejects a leap second, which would move the boundary a second without saying so" do
      expect { authored_instant("2026-12-31T23:59:60Z").normalized }
        .to raise_error(Gitlab::PolicyStore::ValidationError,
          'rule 0: calendar window "eoq" starts_at names a date or time that does not exist: ' \
            '"2026-12-31T23:59:60Z"')
    end

    it "rejects an hour of 24, which names the following midnight" do
      expect { authored_instant("2026-06-15T24:00:00Z").normalized }
        .to raise_error(Gitlab::PolicyStore::ValidationError,
          'rule 0: calendar window "eoq" starts_at names a date or time that does not exist: ' \
            '"2026-06-15T24:00:00Z"')
    end

    it "rejects a timestamp it cannot parse" do
      expect { authored_instant("2026-13-45T00:00:00Z").normalized }
        .to raise_error(Gitlab::PolicyStore::ValidationError,
          'rule 0: calendar window "eoq" has an unparsable starts_at: "2026-13-45T00:00:00Z"')
    end

    it "rejects free text before trying to parse it" do
      expect { authored_instant("next tuesday").normalized }
        .to raise_error(Gitlab::PolicyStore::ValidationError,
          'rule 0: calendar window "eoq" starts_at must be an RFC 3339 instant such as ' \
            '`2026-12-24T00:00:00Z`: "next tuesday"')
    end

    it "rejects a window with a missing bound" do
      expect { authored_instant(nil).normalized }
        .to raise_error(Gitlab::PolicyStore::ValidationError, 'rule 0: calendar window "eoq" requires starts_at')
    end

    it "refuses a bound in an encoding the offset match cannot read, rather than raising from the match" do
      expect { authored_instant("2026-12-24T00:00:00Z".encode("UTF-16LE")).normalized }
        .to raise_error(Gitlab::PolicyStore::ValidationError,
          'rule 0: calendar window "eoq" starts_at must be ASCII to be an ISO 8601 instant, not UTF-16LE')
    end
  end
end
