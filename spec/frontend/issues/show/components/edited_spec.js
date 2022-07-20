import { shallowMount } from '@vue/test-utils';
import Edited from '~/issues/show/components/edited.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

describe('Edited component', () => {
  let wrapper;

  const findAuthorLink = () => wrapper.find('a');
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);
  const formatText = (text) => text.trim().replace(/\s\s+/g, ' ');

  const mountComponent = (propsData) => shallowMount(Edited, { propsData });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders an edited at+by string', () => {
    wrapper = mountComponent({
      updatedAt: '2017-05-15T12:31:04.428Z',
      updatedByName: 'Some User',
      updatedByPath: '/some_user',
    });

    expect(formatText(wrapper.text())).toBe('Edited by Some User');
    expect(findAuthorLink().attributes('href')).toBe('/some_user');
    expect(findTimeAgoTooltip().exists()).toBe(true);
  });

  it('if no updatedAt is provided, no time element will be rendered', () => {
    wrapper = mountComponent({
      updatedByName: 'Some User',
      updatedByPath: '/some_user',
    });

    expect(formatText(wrapper.text())).toBe('Edited by Some User');
    expect(findAuthorLink().attributes('href')).toBe('/some_user');
    expect(findTimeAgoTooltip().exists()).toBe(false);
  });

  it('if no updatedByName and updatedByPath is provided, no user element will be rendered', () => {
    wrapper = mountComponent({
      updatedAt: '2017-05-15T12:31:04.428Z',
    });

    expect(formatText(wrapper.text())).toBe('Edited');
    expect(findAuthorLink().exists()).toBe(false);
    expect(findTimeAgoTooltip().exists()).toBe(true);
  });
});
