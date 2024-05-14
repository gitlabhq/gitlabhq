//
// this component test should be here only temporary until this MR gets sorted:
// https://gitlab.com/gitlab-org/gitlab-ui/-/merge_requests/3969
//
import { shallowMount } from '@vue/test-utils';
import ClearIconButton from '~/search/topbar/components/clear_icon_button.vue';

describe('Clear Icon Button', () => {
  let wrapper;

  const defaultPropsData = {
    title: 'Tooltip Text',
    tooltipContainer: '#divId',
  };

  const createComponent = (propsData = defaultPropsData) => {
    wrapper = shallowMount(ClearIconButton, { propsData });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders successfully', () => {
    expect(wrapper.element).toMatchSnapshot();
  });
});
