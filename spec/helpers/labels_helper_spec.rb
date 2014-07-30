require 'spec_helper'

describe LabelsHelper do
  it { expect(text_color_for_bg('#EEEEEE')).to eq('#333') }
  it { expect(text_color_for_bg('#222E2E')).to eq('#FFF') }
end
