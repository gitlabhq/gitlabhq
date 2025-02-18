import MockAdapter from 'axios-mock-adapter';
import { mount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import createStore from '~/notes/stores';
import IssueSystemNote from '~/vue_shared/components/notes/system_note.vue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { renderGFM } from '~/behaviors/markdown/render_gfm';

jest.mock('~/behaviors/markdown/render_gfm');

describe('system note component', () => {
  let vm;
  let props;
  let mock;

  function createComponent(propsData = {}) {
    const store = createStore();
    store.dispatch('setTargetNoteHash', `note_${props.note.id}`);

    vm = mount(IssueSystemNote, {
      store,
      propsData,
    });
  }

  beforeEach(() => {
    props = {
      note: {
        id: '1424',
        author: {
          id: 1,
          name: 'Root',
          username: 'root',
          state: 'active',
          avatar_url: 'path',
          path: '/root',
        },
        note_html: '<p dir="auto">closed</p>',
        system_note_icon_name: 'status_closed',
        created_at: '2017-08-02T10:51:58.559Z',
      },
    };

    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  it('should render a list item with correct id', () => {
    createComponent(props);

    expect(vm.attributes('id')).toEqual(`note_${props.note.id}`);
  });

  it('should render target class is note is target note', () => {
    createComponent(props);

    expect(vm.classes()).toContain('target');
  });

  it('should render svg icon only for certain icons', () => {
    const ALLOWED_ICONS = [
      'check',
      'merge',
      'merge-request-close',
      'issue-close',
      'issues',
      'error',
      'review-warning',
    ];
    createComponent(props);

    expect(vm.find('[data-testid="timeline-icon"]').exists()).toBe(false);

    ALLOWED_ICONS.forEach((icon) => {
      createComponent({ note: { ...props.note, system_note_icon_name: icon } });
      expect(vm.find('[data-testid="timeline-icon"]').exists()).toBe(true);
    });
  });

  // Redcarpet Markdown renderer wraps text in `<p>` tags
  // we need to strip them because they break layout of commit lists in system notes:
  // https://gitlab.com/gitlab-org/gitlab-foss/uploads/b07a10670919254f0220d3ff5c1aa110/jqzI.png
  it('removes wrapping paragraph from note HTML', () => {
    createComponent(props);

    expect(vm.find('.system-note-message').html()).toContain('<span>closed</span>');
  });

  it('should renderGFM onMount', () => {
    createComponent(props);

    expect(renderGFM).toHaveBeenCalled();
  });

  it('renders outdated code lines', async () => {
    mock
      .onGet('/outdated_line_change_path')
      .reply(HTTP_STATUS_OK, [
        { rich_text: 'console.log', type: 'new', line_code: '123', old_line: null, new_line: 1 },
      ]);

    createComponent({
      note: { ...props.note, outdated_line_change_path: '/outdated_line_change_path' },
    });

    await vm.find("[data-testid='outdated-lines-change-btn']").trigger('click');
    await waitForPromises();

    expect(vm.find("[data-testid='outdated-lines']").exists()).toBe(true);
  });
});
