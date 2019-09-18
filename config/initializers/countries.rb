# frozen_string_literal: true

ISO3166.configure do |config|
  config.locales = [:en]
end

# GitLab permits users to sign up in Ukraine except the Crimean Region: https://about.gitlab.com/handbook/people-operations/code-of-conduct/#trade-compliance-exportimport-control
# This overrides the display name for Ukraine to Ukraine (except Crimean Region)
# To be removed after https://gitlab.com/gitlab-org/gitlab/issues/14784 is implemented
# Data fetched is based on https://github.com/hexorx/countries/blob/master/lib/countries/data/countries/UA.yaml
ISO3166::Data.register(
  continent: "Europe",
  address_format: "|-
  {{recipient}}
  {{street}}
  {{city}} {{region_short}}
  {{postalcode}}
  {{country}}",
  alpha2: "UA",
  alpha3: "UKR",
  country_code: '380',
  international_prefix: '810',
  ioc: "UKR",
  gec: "UP",
  name: "Ukraine (except Crimean Region)",
  national_destination_code_lengths: [2],
  national_number_lengths: [8, 9],
  national_prefix: '8',
  number: '804',
  region: "Europe",
  subregion: "Eastern Europe",
  world_region: "EMEA",
  un_locode: "UA",
  nationality: "Ukrainian",
  vat_rates: {
    standard: 20
  },
  reduced: [7],
  super_reduced: {
    parking: { postal_code: true }
  },
  unofficial_names: %w(Ukraine Ucrania ウクライナ Oekraïne Украина Україна Украіна),
  languages_official: ["uk"],
  languages_spoken: ["uk"],
  geo: {
    latitude: 48.379433,
    latitude_dec: '48.92656326293945',
    longitude: 31.16558,
    longitude_dec: '31.47578239440918',
    max_latitude: 52.37958099999999,
    max_longitude: 40.2285809,
    min_latitude: 44.2924,
    min_longitude: 22.137159,
    bounds: {
      northeast: { lat: 52.37958099999999, lng: 40.2285809 },
      southwest: { lat: 44.2924, lng: 22.137159 }
    }
  },
  currency_code: "UAH",
  start_of_week: "monday"
)
