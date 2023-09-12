import { GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ExternalLinksBlock from '~/ci/job_details/components/sidebar/external_links_block.vue';

describe('External links block', () => {
  let wrapper;

  const createWrapper = (propsData) => {
    wrapper = mountExtended(ExternalLinksBlock, {
      propsData: {
        ...propsData,
      },
    });
  };

  const findAllLinks = () => wrapper.findAllComponents(GlLink);
  const findLink = () => findAllLinks().at(0);

  it('renders a list of links', () => {
    createWrapper({
      externalLinks: [
        {
          label: 'URL 1',
          url: 'https://url1.example.com/',
        },
        {
          label: 'URL 2',
          url: 'https://url2.example.com/',
        },
      ],
    });

    expect(findAllLinks()).toHaveLength(2);
  });

  it('renders a link', () => {
    createWrapper({
      externalLinks: [
        {
          label: 'Example URL',
          url: 'https://example.com/',
        },
      ],
    });

    expect(findLink().text()).toBe('Example URL');
    expect(findLink().attributes('href')).toBe('https://example.com/');
  });
});
