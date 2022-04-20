# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ColorsHelper do
  using RSpec::Parameterized::TableSyntax

  describe '#hex_color_to_rgb_array' do
    context 'valid hex color' do
      where(:hex_color, :rgb_array) do
        '#000000' | [0, 0, 0]
        '#aaaaaa' | [170, 170, 170]
        '#cCcCcC' | [204, 204, 204]
        '#FFFFFF' | [255, 255, 255]
        '#000abc' | [0, 10, 188]
        '#123456' | [18, 52, 86]
        '#a1b2c3' | [161, 178, 195]
        '#000'    | [0, 0, 0]
        '#abc'    | [170, 187, 204]
        '#321'    | [51, 34, 17]
        '#7E2'    | [119, 238, 34]
        '#fFf'    | [255, 255, 255]
      end

      with_them do
        it 'returns correct RGB array' do
          expect(helper.hex_color_to_rgb_array(hex_color)).to eq(rgb_array)
        end
      end
    end

    context 'invalid hex color' do
      where(:hex_color) { ['', '0', '#00', '#ffff', '#1234567', 'invalid', [], 1, nil] }

      with_them do
        it 'raise ArgumentError' do
          expect { helper.hex_color_to_rgb_array(hex_color) }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe '#rgb_array_to_hex_color' do
    context 'valid RGB array' do
      where(:rgb_array, :hex_color) do
        [0, 0, 0]       | '#000000'
        [0, 0, 255]     | '#0000ff'
        [0, 255, 0]     | '#00ff00'
        [255, 0, 0]     | '#ff0000'
        [12, 34, 56]    | '#0c2238'
        [222, 111, 88]  | '#de6f58'
        [255, 255, 255] | '#ffffff'
      end

      with_them do
        it 'returns correct hex color' do
          expect(helper.rgb_array_to_hex_color(rgb_array)).to eq(hex_color)
        end
      end
    end

    context 'invalid RGB array' do
      where(:rgb_array) do
        [
          '',
          '#000000',
          0,
          nil,
          [],
          [0],
          [0, 0],
          [0, 0, 0, 0],
          [-1, 0, 0],
          [0, -1, 0],
          [0, 0, -1],
          [256, 0, 0],
          [0, 256, 0],
          [0, 0, 256]
        ]
      end

      with_them do
        it 'raise ArgumentError' do
          expect { helper.rgb_array_to_hex_color(rgb_array) }.to raise_error(ArgumentError)
        end
      end
    end
  end
end
