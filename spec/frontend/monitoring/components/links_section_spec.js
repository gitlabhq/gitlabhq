import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';

import LinksSection from '~/monitoring/components/links_section.vue';
import { createStore } from '~/monitoring/stores';

describe('Links Section component', () => {
  let store;
  let wrapper;

  const createShallowWrapper = () => {
    wrapper = shallowMount(LinksSection, {
      store,
    });
  };
  const setState = (links) => {
    store.state.monitoringDashboard = {
      ...store.state.monitoringDashboard,
      emptyState: null,
      links,
    };
  };
  const findLinks = () => wrapper.findAllComponents(GlLink);

  beforeEach(() => {
    store = createStore();
    createShallowWrapper();
  });

  it('does not render a section if no links are present', async () => {
    setState();

    await nextTick();

    expect(findLinks().length).toBe(0);
  });

  it('renders a link inside a section', async () => {
    setState([
      {
        title: 'GitLab Website',
        url: 'https://gitlab.com',
      },
    ]);

    await nextTick();
    expect(findLinks()).toHaveLength(1);
    const firstLink = findLinks().at(0);

    expect(firstLink.attributes('href')).toBe('https://gitlab.com');
    expect(firstLink.text()).toBe('GitLab Website');
  });

  it('renders multiple links inside a section', async () => {
    const links = new Array(10)
      .fill(null)
      .map((_, i) => ({ title: `Title ${i}`, url: `https://gitlab.com/projects/${i}` }));
    setState(links);

    await nextTick();
    expect(findLinks()).toHaveLength(10);
  });
});
