import RequestSelector from '~/performance_bar/components/request_selector.vue';
import { shallowMount } from '@vue/test-utils';

describe('request selector', () => {
  const requests = [
    {
      id: '123',
      url: 'https://gitlab.com/',
      hasWarnings: false,
    },
    {
      id: '456',
      url: 'https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/1',
      hasWarnings: false,
    },
    {
      id: '789',
      url: 'https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/1.json?serializer=widget',
      hasWarnings: false,
    },
    {
      id: 'abc',
      url: 'https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/1/discussions.json',
      hasWarnings: true,
    },
  ];

  const wrapper = shallowMount(RequestSelector, {
    propsData: {
      requests,
      currentRequest: requests[1],
    },
  });

  function optionText(requestId) {
    return wrapper
      .find(`[value='${requestId}']`)
      .text()
      .trim();
  }

  it('displays the last component of the path', () => {
    expect(optionText(requests[2].id)).toEqual('1.json?serializer=widget');
  });

  it('keeps the last two components of the path when the last component is numeric', () => {
    expect(optionText(requests[1].id)).toEqual('merge_requests/1');
  });

  it('ignores trailing slashes', () => {
    expect(optionText(requests[0].id)).toEqual('gitlab.com');
  });

  it('has a warning icon if any requests have warnings', () => {
    expect(wrapper.find('span > gl-emoji').element.dataset.name).toEqual('warning');
  });

  it('adds a warning glyph to requests with warnings', () => {
    const requestValue = wrapper.find('[value="abc"]').text();

    expect(requestValue).toContain('discussions.json');
    expect(requestValue).toContain('(!)');
  });
});
