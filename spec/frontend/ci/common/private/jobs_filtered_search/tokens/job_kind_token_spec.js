import { GlFilteredSearchToken, GlFilteredSearchSuggestion } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import JobKindToken from '~/ci/common/private/jobs_filtered_search/tokens/job_kind_token.vue';
import {
  TOKEN_TITLE_JOB_KIND,
  TOKEN_TYPE_JOB_KIND,
} from '~/vue_shared/components/filtered_search_bar/constants';

describe('Job Kind Token', () => {
  let wrapper;

  const findFilteredSearchToken = () => wrapper.findComponent(GlFilteredSearchToken);
  const findAllFilteredSearchSuggestions = () =>
    wrapper.findAllComponents(GlFilteredSearchSuggestion);

  const defaultProps = {
    config: {
      type: TOKEN_TYPE_JOB_KIND,
      icon: 'kind',
      title: TOKEN_TITLE_JOB_KIND,
      unique: true,
    },
    value: {
      data: '',
    },
    cursorPosition: 'start',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(JobKindToken, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlFilteredSearchToken: stubComponent(GlFilteredSearchToken, {
          template: `
            <div>
              <div class="view-slot"><slot name="view"></slot></div>
              <div class="suggestions-slot"><slot name="suggestions"></slot></div>
            </div>
          `,
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

  it('renders all job kinds available', () => {
    expect(findAllFilteredSearchSuggestions()).toHaveLength(2);
  });
});
