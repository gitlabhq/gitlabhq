import { GlFilteredSearchToken, GlFilteredSearchSuggestion, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import JobStatusToken from '~/ci/common/private/jobs_filtered_search/tokens/job_status_token.vue';
import {
  TOKEN_TITLE_STATUS,
  TOKEN_TYPE_STATUS,
} from '~/vue_shared/components/filtered_search_bar/constants';

describe('Job Status Token', () => {
  let wrapper;

  const findFilteredSearchToken = () => wrapper.findComponent(GlFilteredSearchToken);
  const findAllFilteredSearchSuggestions = () =>
    wrapper.findAllComponents(GlFilteredSearchSuggestion);
  const findAllGlIcons = () => wrapper.findAllComponents(GlIcon);

  const defaultProps = {
    config: {
      type: TOKEN_TYPE_STATUS,
      icon: 'status',
      title: TOKEN_TITLE_STATUS,
      unique: true,
    },
    value: {
      data: '',
    },
    cursorPosition: 'start',
  };

  const createComponent = () => {
    wrapper = shallowMount(JobStatusToken, {
      propsData: {
        ...defaultProps,
      },
      stubs: {
        GlFilteredSearchToken: stubComponent(GlFilteredSearchToken, {
          template: `<div><slot name="suggestions"></slot></div>`,
        }),
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('passes config correctly', () => {
    expect(findFilteredSearchToken().props('config')).toEqual(defaultProps.config);
  });

  it('renders all job statuses available', () => {
    const expectedLength = 11;

    expect(findAllFilteredSearchSuggestions()).toHaveLength(expectedLength);
    expect(findAllGlIcons()).toHaveLength(expectedLength);
  });
});
