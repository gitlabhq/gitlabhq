import { GlSprintf } from '@gitlab/ui';
import random from 'lodash/random';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CommandPaletteLottery from '~/super_sidebar/components/global_search/command_palette/command_palette_lottery.vue';

jest.mock('lodash/random');

describe('CommandPaletteLottery', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(CommandPaletteLottery);
  };

  const findGlSprintf = () => wrapper.findComponent(GlSprintf);

  it('should render the search scope', () => {
    random.mockImplementation(() => 0);
    createComponent();

    expect(findGlSprintf().attributes('message')).toContain(
      'Type %{linkStart}@%{linkEnd} to search for users',
    );
  });
});
