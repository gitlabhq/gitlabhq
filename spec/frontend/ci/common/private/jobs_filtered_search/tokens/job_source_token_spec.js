import { GlFilteredSearchToken, GlFilteredSearchSuggestion } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import JobSourceToken from '~/ci/common/private/jobs_filtered_search/tokens/job_source_token.vue';
import { JOB_SOURCES } from 'ee_else_ce/ci/common/private/jobs_filtered_search/tokens/constants';
import {
  TOKEN_TITLE_JOBS_SOURCE,
  TOKEN_TYPE_JOBS_SOURCE,
} from '~/vue_shared/components/filtered_search_bar/constants';

describe('Job Source Token', () => {
  let wrapper;

  const findFilteredSearchToken = () => wrapper.findComponent(GlFilteredSearchToken);
  const findAllFilteredSearchSuggestions = () =>
    wrapper.findAllComponents(GlFilteredSearchSuggestion);
  const findActiveSourceText = () => wrapper.find('[data-testid="job-source-text"]').text();

  const defaultProps = {
    config: {
      type: TOKEN_TYPE_JOBS_SOURCE,
      icon: 'trigger-source',
      title: TOKEN_TITLE_JOBS_SOURCE,
      unique: true,
    },
    value: {
      data: '',
    },
    cursorPosition: 'start',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(JobSourceToken, {
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

  it('renders all job sources available', () => {
    expect(findAllFilteredSearchSuggestions()).toHaveLength(JOB_SOURCES.length);
  });

  it('updates the displayed text when value prop changes', async () => {
    // Start with web source
    createComponent({
      value: { data: 'WEB' },
    });

    expect(findActiveSourceText()).toBe('Web');

    // Update to pipeline source
    await wrapper.setProps({
      value: { data: 'PIPELINE' },
    });

    expect(findActiveSourceText()).toBe('Pipeline');
  });
});
