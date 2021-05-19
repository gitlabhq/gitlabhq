import { shallowMount } from '@vue/test-utils';
import SettingsTitles from '~/packages_and_registries/settings/group/components/settings_titles.vue';

describe('settings_titles', () => {
  let wrapper;

  const mountComponent = () => {
    wrapper = shallowMount(SettingsTitles, {
      propsData: {
        title: 'foo',
        subTitle: 'bar',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders properly', () => {
    mountComponent();

    expect(wrapper.element).toMatchSnapshot();
  });
});
