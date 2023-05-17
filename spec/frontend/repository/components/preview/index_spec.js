import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { handleLocationHash } from '~/lib/utils/common_utils';
import waitForPromises from 'helpers/wait_for_promises';
import Preview from '~/repository/components/preview/index.vue';

const PROPS_DATA = {
  blob: {
    webPath: 'http://test.com',
    name: 'README.md',
  },
};

const MOCK_README_DATA = {
  __typename: 'ReadmeFile',
  html: '<div class="blob">test</div>',
};

jest.mock('~/lib/utils/common_utils');

Vue.use(VueApollo);

let wrapper;
let mockApollo;
let mockReadmeData;

const mockResolvers = {
  Query: {
    readme: () => mockReadmeData(),
  },
};

function createComponent() {
  mockApollo = createMockApollo([], mockResolvers);

  return shallowMount(Preview, {
    propsData: PROPS_DATA,
    apolloProvider: mockApollo,
  });
}

describe('Repository file preview component', () => {
  beforeEach(() => {
    mockReadmeData = jest.fn();
    wrapper = createComponent();
    mockReadmeData.mockResolvedValue(MOCK_README_DATA);
  });

  it('handles hash after render', async () => {
    await waitForPromises();
    expect(handleLocationHash).toHaveBeenCalled();
  });

  it('renders loading icon', () => {
    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
  });
});
