require 'spec_helper'

describe 'Projects > Files > User uses soft wrap whilst editing file', :js do
  before do
    project = create(:project, :repository)
    user = project.owner
    sign_in user
    visit project_new_blob_path(project, 'master', file_name: 'test_file-name')
    page.within('.file-editor.code') do
      find('.ace_text-input', visible: false).send_keys 'Touch water with paw then recoil in horror chase dog then
        run away chase the pig around the house eat owner\'s food, and knock
        dish off table head butt cant eat out of my own dish. Cat is love, cat
        is life rub face on everything poop on grasses so meow. Playing with
        balls of wool flee in terror at cucumber discovered on floor run in
        circles tuxedo cats always looking dapper, but attack dog, run away
        and pretend to be victim so all of a sudden cat goes crazy, yet chase
        laser. Make muffins sit in window and stare ooo, a bird! yum lick yarn
        hanging out of own butt jump off balcony, onto stranger\'s head yet
        chase laser. Purr for no reason stare at ceiling hola te quiero.'.squish
    end
  end

  let(:toggle_button) { find('.soft-wrap-toggle') }

  it 'user clicks the "Soft wrap" button and then "No wrap" button' do
    wrapped_content_width = get_content_width
    toggle_button.click
    expect(toggle_button).to have_content 'No wrap'
    unwrapped_content_width = get_content_width
    expect(unwrapped_content_width).to be < wrapped_content_width

    toggle_button.click
    expect(toggle_button).to have_content 'Soft wrap'
    expect(get_content_width).to be > unwrapped_content_width
  end

  def get_content_width
    find('.ace_content')[:style].slice!(/width: \d+/).slice!(/\d+/).to_i
  end
end
