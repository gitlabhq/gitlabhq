import { shallowMount } from '@vue/test-utils';
import RequestSelector from '~/performance_bar/components/request_selector.vue';

describe('request selector', () => {
  const requests = [
    {
      id: 'warningReq',
      url: 'https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/1/discussions.json',
      truncatedUrl: 'discussions.json',
      hasWarnings: true,
    },
  ];

  const wrapper = shallowMount(RequestSelector, {
    propsData: {
      requests,
      currentRequest: requests[0],
    },
  });

  it('has a warning icon if any requests have warnings', () => {
    expect(wrapper.find('span > gl-emoji').element.dataset.name).toEqual('warning');
  });

  it('adds a warning glyph to requests with warnings', () => {
    const requestValue = wrapper.find('[value="warningReq"]').text();

    expect(requestValue).toContain('discussions.json');
    expect(requestValue).toContain('(!)');
  });
});
