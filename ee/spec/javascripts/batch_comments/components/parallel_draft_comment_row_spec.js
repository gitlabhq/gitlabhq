import Vue from 'vue';
import ParallelDraftCommentRow from 'ee/batch_comments/components/parallel_draft_comment_row.vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { createStore } from '~/mr_notes/stores';
import '~/behaviors/markdown/render_gfm';
import { createDraft } from '../mock_data';

describe('Batch comments parallel draft row component', () => {
  let vm;
  let Component;
  let draft;

  beforeAll(() => {
    Component = Vue.extend(ParallelDraftCommentRow);
  });

  beforeEach(() => {
    draft = createDraft();
  });

  afterEach(() => {
    vm.$destroy();
  });

  ['left', 'right'].forEach(side => {
    describe(`${side} side of diff`, () => {
      beforeEach(() => {
        const store = createStore();

        vm = createComponentWithStore(Component, store, {
          line: { code: '1' },
          diffFileContentSha: 'test',
        });

        spyOnProperty(vm, 'draftForLine').and.returnValue((sha, line, draftSide) => {
          if (draftSide === side) return draft;

          return {};
        });

        vm.$mount();
      });

      it(`it renders draft on ${side} side`, () => {
        const sideClass = side === 'left' ? '.old' : '.new';
        const oppositeSideClass = side === 'left' ? '.new' : '.old';

        expect(vm.$el.querySelector(`.parallel${sideClass} .draft-note-component`)).not.toBe(null);
        expect(vm.$el.querySelector(`.parallel${oppositeSideClass} .draft-note-component`)).toBe(
          null,
        );
      });
    });
  });
});
