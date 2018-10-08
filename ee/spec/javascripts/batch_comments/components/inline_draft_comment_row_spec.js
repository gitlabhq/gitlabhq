import Vue from 'vue';
import InlineDraftCommentRow from 'ee/batch_comments/components/inline_draft_comment_row.vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { createStore } from 'ee/batch_comments/stores';
import '~/behaviors/markdown/render_gfm';
import { createDraft } from '../mock_data';

describe('Batch comments inline draft row component', () => {
  let vm;
  let Component;
  let draft;

  beforeAll(() => {
    Component = Vue.extend(InlineDraftCommentRow);
  });

  beforeEach(() => {
    const store = createStore();

    draft = createDraft();

    vm = mountComponentWithStore(Component, { store, props: { draft } });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders draft', () => {
    expect(vm.$el.querySelector('.draft-note-component')).not.toBe(null);
  });
});
