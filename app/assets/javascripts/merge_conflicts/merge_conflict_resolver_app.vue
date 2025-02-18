<script>
import { GlSprintf, GlButton, GlButtonGroup, GlLoadingIcon } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapGetters, mapState, mapActions } from 'vuex';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { __ } from '~/locale';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import DiffFileEditor from './components/diff_file_editor.vue';
import InlineConflictLines from './components/inline_conflict_lines.vue';
import ParallelConflictLines from './components/parallel_conflict_lines.vue';
import { INTERACTIVE_RESOLVE_MODE } from './constants';

/**
 * A lot of the classes below should
 * be replaced with GitLab UI components.
 *
 * We are just doing it temporarily in order to migrate the template from HAML => Vue in an iterative manner
 * and are going to clean it up as part of:
 *
 * https://gitlab.com/gitlab-org/gitlab/-/issues/321090
 *
 */
export default {
  components: {
    GlButton,
    GlButtonGroup,
    ClipboardButton,
    GlSprintf,
    GlLoadingIcon,
    FileIcon,
    DiffFileEditor,
    InlineConflictLines,
    ParallelConflictLines,
  },
  inject: ['mergeRequestPath', 'sourceBranchPath', 'resolveConflictsPath'],
  i18n: {
    commitStatSummary: __('Showing %{conflict}'),
    resolveInfo: __(
      'Resolve source branch %{source_branch_name} conflicts using interactive mode to select %{use_ours} or %{use_theirs}, or manually using %{edit_inline}.',
    ),
  },
  computed: {
    ...mapGetters([
      'getConflictsCountText',
      'isReadyToCommit',
      'getCommitButtonText',
      'fileTextTypePresent',
    ]),
    ...mapState(['isLoading', 'hasError', 'isParallel', 'conflictsData']),
    commitMessage: {
      get() {
        return this.conflictsData.commitMessage;
      },
      set(value) {
        this.updateCommitMessage(value);
      },
    },
  },
  methods: {
    ...mapActions([
      'setViewType',
      'submitResolvedConflicts',
      'setFileResolveMode',
      'setPromptConfirmationState',
      'updateCommitMessage',
    ]),
    onClickResolveModeButton(file, mode) {
      if (mode === INTERACTIVE_RESOLVE_MODE && file.resolveEditChanged) {
        this.setPromptConfirmationState({ file, promptDiscardConfirmation: true });
      } else {
        this.setFileResolveMode({ file, mode });
      }
    },
  },
};
</script>
<template>
  <div id="conflicts">
    <div data-testid="resolve-info">
      <gl-sprintf :message="$options.i18n.resolveInfo">
        <template #source_branch_name>
          <a class="ref-name" :href="sourceBranchPath">{{ conflictsData.sourceBranch }}</a>
        </template>
        <template #use_ours>
          <strong>{{ s__('MergeConflict|Use ours') }}</strong>
        </template>
        <template #use_theirs>
          <strong>{{ s__('MergeConflict|Use theirs') }}</strong>
        </template>
        <template #edit_inline>
          <strong>{{ s__('MergeConflict|Edit inline') }}</strong>
        </template>
      </gl-sprintf>
    </div>
    <gl-loading-icon v-if="isLoading" size="lg" data-testid="loading-spinner" />
    <div v-if="hasError" class="nothing-here-block">
      {{ conflictsData.errorMessage }}
    </div>
    <template v-if="!isLoading && !hasError">
      <div class="gl-border-b-0 gl-py-5 gl-leading-32">
        <div v-if="fileTextTypePresent" class="gl-float-right">
          <gl-button-group>
            <gl-button :selected="!isParallel" @click="setViewType('inline')">
              {{ __('Inline') }}
            </gl-button>
            <gl-button
              :selected="isParallel"
              data-testid="side-by-side"
              @click="setViewType('parallel')"
            >
              {{ __('Side-by-side') }}
            </gl-button>
          </gl-button-group>
        </div>
        <div class="js-toggle-container">
          <div data-testid="conflicts-count">
            <gl-sprintf :message="$options.i18n.commitStatSummary">
              <template #conflict>
                <strong class="gl-text-danger">{{ getConflictsCountText }}</strong>
              </template>
              <template #sourceBranch>
                <strong class="ref-name">{{ conflictsData.sourceBranch }}</strong>
              </template>
              <template #targetBranch>
                <strong class="ref-name">{{ conflictsData.targetBranch }}</strong>
              </template>
            </gl-sprintf>
          </div>
        </div>
      </div>
      <div class="files-wrapper">
        <div class="files">
          <div
            v-for="file in conflictsData.files"
            :key="file.blobPath"
            class="diff-file file-holder conflict"
            data-testid="files"
          >
            <div class="js-file-title file-title file-title-flex-parent cursor-default">
              <div class="file-header-content" data-testid="file-name">
                <file-icon :file-name="file.filePath" :size="16" css-classes="gl-mr-2" />
                <strong class="file-title-name gl-break-all">{{ file.filePath }}</strong>
                <clipboard-button
                  :title="__('Copy file path')"
                  :text="file.filePath"
                  size="small"
                  category="tertiary"
                />
              </div>
              <div class="file-actions gl-ml-auto gl-flex gl-items-center gl-self-start">
                <gl-button-group v-if="file.type === 'text'" class="gl-mr-3">
                  <gl-button
                    :selected="file.resolveMode === 'interactive'"
                    data-testid="interactive-button"
                    @click="onClickResolveModeButton(file, 'interactive')"
                  >
                    {{ __('Interactive mode') }}
                  </gl-button>
                  <gl-button
                    :selected="file.resolveMode === 'edit'"
                    data-testid="inline-button"
                    @click="onClickResolveModeButton(file, 'edit')"
                  >
                    {{ __('Edit inline') }}
                  </gl-button>
                </gl-button-group>
                <gl-button :href="file.blobPath">
                  <gl-sprintf :message="__('View file @ %{commitSha}')">
                    <template #commitSha>
                      {{ conflictsData.shortCommitSha }}
                    </template>
                  </gl-sprintf>
                </gl-button>
              </div>
            </div>
            <div class="diff-content diff-wrap-lines gl-rounded-b-base">
              <div
                v-if="file.resolveMode === 'interactive' && file.type === 'text'"
                class="file-content gl-rounded-b-base"
              >
                <parallel-conflict-lines v-if="isParallel" :file="file" />
                <inline-conflict-lines v-else :file="file" />
              </div>
              <diff-file-editor
                v-if="file.resolveMode === 'edit' || file.type === 'text-editor'"
                :file="file"
              />
            </div>
          </div>
        </div>
      </div>
      <div class="resolve-conflicts-form gl-mt-6">
        <div class="form-group row">
          <div class="col-md-8">
            <label class="label-bold" for="commit-message">
              {{ __('Commit message') }}
            </label>
            <div class="commit-message-container gl-mb-4">
              <div class="max-width-marker"></div>
              <textarea
                id="commit-message"
                v-model="commitMessage"
                data-testid="commit-message"
                class="form-control js-commit-message"
                rows="5"
              ></textarea>
            </div>
            <gl-button
              :disabled="!isReadyToCommit"
              variant="confirm"
              class="js-submit-button gl-mr-2"
              @click="submitResolvedConflicts(resolveConflictsPath)"
            >
              {{ getCommitButtonText }}
            </gl-button>
            <gl-button :href="mergeRequestPath">
              {{ __('Cancel') }}
            </gl-button>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>
