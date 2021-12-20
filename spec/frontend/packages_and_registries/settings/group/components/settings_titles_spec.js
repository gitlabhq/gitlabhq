import { shallowMount } from '@vue/test-utils';
import SettingsTitles from '~/packages_and_registries/settings/group/components/settings_titles.vue';

describe('settings_titles', () => {
  let wrapper;

  const defaultProps = {
    title: 'foo',
    subTitle: 'bar',
  };

  const mountComponent = (propsData = defaultProps) => {
    wrapper = shallowMount(SettingsTitles, {
      propsData,
    });
  };

  const findSubTitle = () => wrapper.find('p');

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders properly', () => {
    mountComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('does not render the subtitle paragraph when no subtitle is passed', () => {
    mountComponent({ title: defaultProps.title });

    expect(findSubTitle().exists()).toBe(false);
  });
});
