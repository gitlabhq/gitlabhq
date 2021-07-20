<script>
import { GlSprintf, GlButton, GlButtonGroup } from '@gitlab/ui';
import { mapGetters, mapState, mapActions } from 'vuex';
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
    GlSprintf,
    FileIcon,
    DiffFileEditor,
    InlineConflictLines,
    ParallelConflictLines,
  },
  inject: ['mergeRequestPath', 'sourceBranchPath', 'resolveConflictsPath'],
  i18n: {
    commitStatSummary: __('Showing %{conflict} between %{sourceBranch} and %{targetBranch}'),
    resolveInfo: __(
      'You can resolve the merge conflict using either the Interactive mode, by choosing %{use_ours} or %{use_theirs} buttons, or by editing the files directly. Commit these changes into %{branch_name}',
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
    <div v-if="isLoading" class="loading">
      <div class="spinner spinner-md"></div>
    </div>
    <div v-if="hasError" class="nothing-here-block">
      {{ conflictsData.errorMessage }}
    </div>
    <template v-if="!isLoading && !hasError">
      <div class="gl-border-b-0 gl-py-5 gl-line-height-32">
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
                <strong class="cred">{{ getConflictsCountText }}</strong>
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
                <strong class="file-title-name">{{ file.filePath }}</strong>
              </div>
              <div class="file-actions d-flex align-items-center gl-ml-auto gl-align-self-start">
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
            <div class="diff-content diff-wrap-lines">
              <div
                v-if="file.resolveMode === 'interactive' && file.type === 'text'"
                class="file-content"
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
      <hr />
      <div class="resolve-conflicts-form">
        <div class="form-group row">
          <div class="col-md-4">
            <h4 class="gl-mt-0">
              {{ __('Resolve conflicts on source branch') }}
            </h4>
            <div class="gl-mb-5" data-testid="resolve-info">
              <gl-sprintf :message="$options.i18n.resolveInfo">
                <template #use_ours>
                  <code>{{ s__('MergeConflict|Use ours') }}</code>
                </template>
                <template #use_theirs>
                  <code>{{ s__('MergeConflict|Use theirs') }}</code>
                </template>
                <template #branch_name>
                  <a class="ref-name" :href="sourceBranchPath">
                    {{ conflictsData.sourceBranch }}
                  </a>
                </template>
              </gl-sprintf>
            </div>
          </div>
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
              class="js-submit-button"
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
