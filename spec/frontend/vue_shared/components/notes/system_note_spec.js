import { mount } from '@vue/test-utils';
import IssueSystemNote from '~/vue_shared/components/notes/system_note.vue';
import createStore from '~/notes/stores';
import initMRPopovers from '~/mr_popover/index';

jest.mock('~/mr_popover/index', () => jest.fn());

describe('system note component', () => {
  let vm;
  let props;

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

    const store = createStore();
    store.dispatch('setTargetNoteHash', `note_${props.note.id}`);

    vm = mount(IssueSystemNote, {
      store,
      propsData: props,
      attachToDocument: true,
      sync: false,
    });
  });

  afterEach(() => {
    vm.destroy();
  });

  it('should render a list item with correct id', () => {
    expect(vm.attributes('id')).toEqual(`note_${props.note.id}`);
  });

  it('should render target class is note is target note', () => {
    expect(vm.classes()).toContain('target');
  });

  it('should render svg icon', () => {
    expect(vm.find('.timeline-icon svg').exists()).toBe(true);
  });

  // Redcarpet Markdown renderer wraps text in `<p>` tags
  // we need to strip them because they break layout of commit lists in system notes:
  // https://gitlab.com/gitlab-org/gitlab-foss/uploads/b07a10670919254f0220d3ff5c1aa110/jqzI.png
  it('removes wrapping paragraph from note HTML', () => {
    expect(vm.find('.system-note-message').html()).toContain('<span>closed</span>');
  });

  it('should initMRPopovers onMount', () => {
    expect(initMRPopovers).toHaveBeenCalled();
  });
});
