import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import WorkItemSystemNote from '~/work_items/components/notes/system_note.vue';
import { workItemSystemNoteWithMetadata } from 'jest/work_items/mock_data';
import axios from '~/lib/utils/axios_utils';

jest.mock('~/behaviors/markdown/render_gfm');

describe('Work Items system note component', () => {
  let wrapper;
  let mock;

  const createComponent = ({ note = workItemSystemNoteWithMetadata } = {}) => {
    mock = new MockAdapter(axios);

    wrapper = shallowMount(WorkItemSystemNote, {
      propsData: {
        note,
      },
    });
  };

  const findTimelineIcon = () => wrapper.findComponent(GlIcon);
  const findComparePreviousVersionButton = () => wrapper.find('[data-testid="compare-btn"]');

  beforeEach(() => {
    createComponent();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  it('should render a list item with correct id', () => {
    expect(wrapper.attributes('id')).toBe(
      `note_${getIdFromGraphQLId(workItemSystemNoteWithMetadata.id)}`,
    );
  });

  it('should render svg icon only for allowed icons', () => {
    expect(findTimelineIcon().exists()).toBe(false);

    const ALLOWED_ICONS = ['issue-close'];
    ALLOWED_ICONS.forEach((icon) => {
      createComponent({ note: { ...workItemSystemNoteWithMetadata, systemNoteIconName: icon } });
      expect(findTimelineIcon().exists()).toBe(true);
    });
  });

  it('should not show compare previous version for FOSS', () => {
    expect(findComparePreviousVersionButton().exists()).toBe(false);
  });
});
