import { GlIcon } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import WorkItemSystemNote from '~/work_items/components/notes/system_note.vue';
import NoteHeader from '~/notes/components/note_header.vue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

jest.mock('~/behaviors/markdown/render_gfm');

describe('system note component', () => {
  let wrapper;
  let props;
  let mock;

  const findTimelineIcon = () => wrapper.findComponent(GlIcon);
  const findSystemNoteMessage = () => wrapper.findComponent(NoteHeader);
  const findOutdatedLineButton = () =>
    wrapper.findComponent('[data-testid="outdated-lines-change-btn"]');
  const findOutdatedLines = () => wrapper.findComponent('[data-testid="outdated-lines"]');

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(WorkItemSystemNote, {
      propsData,
      slots: {
        'extra-controls':
          '<gl-button data-testid="outdated-lines-change-btn">Compare with last version</gl-button>',
      },
    });
  };

  beforeEach(() => {
    props = {
      note: {
        id: '1424',
        author: {
          id: 1,
          name: 'Root',
          username: 'root',
          state: 'active',
          avatarUrl: 'path',
          path: '/root',
        },
        bodyHtml: '<p dir="auto">closed</p>',
        systemNoteIconName: 'status_closed',
        createdAt: '2017-08-02T10:51:58.559Z',
      },
    };

    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  it('should render a list item with correct id', () => {
    createComponent(props);

    expect(wrapper.attributes('id')).toBe(`note_${props.note.id}`);
  });

  // Note: The test case below is to handle a use case related to vuex store but since this does not
  // have a vuex store , disabling it now will be fixing it in the next iteration
  // eslint-disable-next-line jest/no-disabled-tests
  it.skip('should render target class is note is target note', () => {
    createComponent(props);

    expect(wrapper.classes()).toContain('target');
  });

  it('should render svg icon', () => {
    createComponent(props);

    expect(findTimelineIcon().exists()).toBe(true);
  });

  // Redcarpet Markdown renderer wraps text in `<p>` tags
  // we need to strip them because they break layout of commit lists in system notes:
  // https://gitlab.com/gitlab-org/gitlab-foss/uploads/b07a10670919254f0220d3ff5c1aa110/jqzI.png
  it('removes wrapping paragraph from note HTML', () => {
    createComponent(props);

    expect(findSystemNoteMessage().html()).toContain('<span>closed</span>');
  });

  it('should renderGFM onMount', () => {
    createComponent(props);

    expect(renderGFM).toHaveBeenCalled();
  });

  // eslint-disable-next-line jest/no-disabled-tests
  it.skip('renders outdated code lines', async () => {
    mock
      .onGet('/outdated_line_change_path')
      .reply(HTTP_STATUS_OK, [
        { rich_text: 'console.log', type: 'new', line_code: '123', old_line: null, new_line: 1 },
      ]);

    createComponent({
      note: { ...props.note, outdated_line_change_path: '/outdated_line_change_path' },
    });

    await findOutdatedLineButton().vm.$emit('click');
    await waitForPromises();

    expect(findOutdatedLines().exists()).toBe(true);
  });
});
