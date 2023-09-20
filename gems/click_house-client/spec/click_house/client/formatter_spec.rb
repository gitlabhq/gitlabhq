# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Client::Formatter do
  it 'formats values according to types in metadata' do
    # this query here is just for documentation purposes, it generates the response below
    _query = <<~SQL.squish
      SELECT toUInt64(1) as uint64,
             toDateTime64('2016-06-15 23:00:00', 6, 'UTC') as datetime64_6,
             INTERVAL 1 second as interval_second
    SQL

    response_json = <<~JSON
{
	"meta":
	[
		{
			"name": "uint64",
			"type": "UInt64"
		},
		{
			"name": "datetime64_6",
			"type": "DateTime64(6, 'UTC')"
		},
		{
			"name": "interval_second",
			"type": "IntervalSecond"
		}
	],

	"data":
	[
		{
			"uint64": "1",
			"datetime64_6": "2016-06-15 23:00:00.000000",
			"interval_second": "1"
		}
	],

	"rows": 1,

	"statistics":
	{
		"elapsed": 0.002101,
		"rows_read": 1,
		"bytes_read": 1
	}
}
    JSON

    parsed_response = JSON.parse(response_json)
    formatted_response = described_class.format(parsed_response)

    expect(formatted_response).to(
      eq(
        [{ "uint64" => 1,
           "datetime64_6" => ActiveSupport::TimeZone["UTC"].parse("2016-06-15 23:00:00"),
           "interval_second" => 1.second }]
      )
    )
  end
end
