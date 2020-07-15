import { shallowMount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import { createStore } from '~/monitoring/stores';
import LinksSection from '~/monitoring/components/links_section.vue';

describe('Links Section component', () => {
  let store;
  let wrapper;

  const createShallowWrapper = () => {
    wrapper = shallowMount(LinksSection, {
      store,
    });
  };
  const setState = links => {
    store.state.monitoringDashboard = {
      ...store.state.monitoringDashboard,
      emptyState: null,
      links,
    };
  };
  const findLinks = () => wrapper.findAll(GlLink);

  beforeEach(() => {
    store = createStore();
    createShallowWrapper();
  });

  it('does not render a section if no links are present', () => {
    setState();

    return wrapper.vm.$nextTick(() => {
      expect(findLinks()).not.toExist();
    });
  });

  it('renders a link inside a section', () => {
    setState([
      {
        title: 'GitLab Website',
        url: 'https://gitlab.com',
      },
    ]);

    return wrapper.vm.$nextTick(() => {
      expect(findLinks()).toHaveLength(1);
      const firstLink = findLinks().at(0);

      expect(firstLink.attributes('href')).toBe('https://gitlab.com');
      expect(firstLink.text()).toBe('GitLab Website');
    });
  });

  it('renders multiple links inside a section', () => {
    const links = new Array(10)
      .fill(null)
      .map((_, i) => ({ title: `Title ${i}`, url: `https://gitlab.com/projects/${i}` }));
    setState(links);

    return wrapper.vm.$nextTick(() => {
      expect(findLinks()).toHaveLength(10);
    });
  });
});
