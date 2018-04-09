<script>
  /**
   * Common component to render a system note, icon and user information.
   *
   * This component needs to be used with a vuex store.
   * That vuex store needs to have a `targetNoteHash` getter
   *
   * @example
   * <system-note
   *   :note="{
   *     id: String,
   *     author: Object,
   *     createdAt: String,
   *     note_html: String,
   *     system_note_icon_name: String
   *    }"
   *   />
   */
  import $ from 'jquery';
  import { mapGetters } from 'vuex';
  import noteHeader from '~/notes/components/note_header.vue';
  import { spriteIcon } from '../../../lib/utils/common_utils';
  import Icon from '~/vue_shared/components/icon.vue'

  const MAX_VISIBLE_COMMIT_LIST_COUNT = 3;

  export default {
    name: 'SystemNote',
    components: {
      Icon,
      noteHeader,
    },
    props: {
      note: {
        type: Object,
        required: true,
      },
    },
    data() {
      return {
        expanded: false,
      };
    },
    computed: {
      ...mapGetters([
        'targetNoteHash',
      ]),
      noteAnchorId() {
        return `note_${this.note.id}`;
      },
      isTargetNote() {
        return this.targetNoteHash === this.noteAnchorId;
      },
      iconHtml() {
        return spriteIcon(this.note.system_note_icon_name);
      },
      toggleIcon() {
        return this.expanded ? 'chevron-up' : 'chevron-down';
      },
      // following 2 methods taken from code in `collapseLongCommitList` of notes.js:
      actionTextHtml() {
        return $(this.note.note_html)
          .first()
          .text()
          .replace(':', '');
      },
      hasMoreCommits() {
        return $(this.note.note_html)
           .filter('ul')
           .children()
           .length > MAX_VISIBLE_COMMIT_LIST_COUNT;
      },
    },
  };
</script>

<template>
  <li
    :id="noteAnchorId"
    :class="{ target: isTargetNote }"
    class="note system-note timeline-entry">
    <div class="timeline-entry-inner">
      <div
        class="timeline-icon"
        v-html="iconHtml">
      </div>
      <div class="timeline-content">
        <div class="note-header">
          <note-header
            :author="note.author"
            :created-at="note.created_at"
            :note-id="note.id"
            :action-text-html="actionTextHtml"
          />
        </div>
        <div class="note-body">
          <div
            v-html="note.note_html"
            class="note-text"
            :class="{
              'system-note-commit-list': hasMoreCommits,
              'hide-shade': expanded
            }"
          ></div>
          <div
            v-if="hasMoreCommits"
            class="flex-list"
          >
            <div
              @click="expanded = !expanded"
              class="system-note-commit-list-toggler flex-row"
            >
              <Icon
                :name="toggleIcon"
                :size="8"
                class="append-right-5"
              />
              <span>Toggle commit list</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </li>
</template>
