<script>
/* eslint-disable @gitlab/vue-require-i18n-strings */
import { GlIcon, GlModal } from '@gitlab/ui';
import ShortcutsToggle from './shortcuts_toggle.vue';

export default {
  components: {
    GlIcon,
    GlModal,
    ShortcutsToggle,
  },
  computed: {
    ctrlCharacter() {
      return window.gl.client.isMac ? '⌘' : 'ctrl';
    },
    onDotCom() {
      return window.gon.dot_com;
    },
  },
};
</script>
<template>
  <gl-modal
    modal-id="keyboard-shortcut-modal"
    size="lg"
    data-testid="modal-shortcuts"
    :visible="true"
    :hide-footer="true"
    @hidden="$emit('hidden')"
  >
    <template #modal-title>
      <shortcuts-toggle />
    </template>
    <div class="row">
      <div class="col-lg-4">
        <table class="shortcut-mappings text-2">
          <tbody>
            <tr>
              <th></th>
              <th>{{ __('Global Shortcuts') }}</th>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>?</kbd>
              </td>
              <td>{{ __('Toggle this dialog') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>shift p</kbd>
              </td>
              <td>{{ __('Go to your projects') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>shift g</kbd>
              </td>
              <td>{{ __('Go to your groups') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>shift a</kbd>
              </td>
              <td>{{ __('Go to the activity feed') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>shift l</kbd>
              </td>
              <td>{{ __('Go to the milestone list') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>shift s</kbd>
              </td>
              <td>{{ __('Go to your snippets') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>s</kbd>
                /
                <kbd>/</kbd>
              </td>
              <td>{{ __('Start search') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>shift i</kbd>
              </td>
              <td>{{ __('Go to your issues') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>shift m</kbd>
              </td>
              <td>{{ __('Go to your merge requests') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>shift t</kbd>
              </td>
              <td>{{ __('Go to your To-Do list') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>p</kbd>
                <kbd>b</kbd>
              </td>
              <td>{{ __('Toggle the Performance Bar') }}</td>
            </tr>
            <tr v-if="onDotCom">
              <td class="shortcut">
                <kbd>g</kbd>
                <kbd>x</kbd>
              </td>
              <td>{{ __('Toggle GitLab Next') }}</td>
            </tr>
          </tbody>
          <tbody>
            <tr>
              <th></th>
              <th>{{ __('Editing') }}</th>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>{{ ctrlCharacter }} shift p</kbd>
              </td>
              <td>{{ __('Toggle Markdown preview') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>
                  <gl-icon name="arrow-up" />
                </kbd>
              </td>
              <td>
                {{ __('Edit your most recent comment in a thread (from an empty textarea)') }}
              </td>
            </tr>
          </tbody>
          <tbody>
            <tr>
              <th></th>
              <th>{{ __('Wiki') }}</th>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>e</kbd>
              </td>
              <td>{{ __('Edit wiki page') }}</td>
            </tr>
          </tbody>
          <tbody>
            <tr>
              <th></th>
              <th>{{ __('Repository Graph') }}</th>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>
                  <gl-icon name="arrow-left" />
                </kbd>
                /
                <kbd>h</kbd>
              </td>
              <td>{{ __('Scroll left') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>
                  <gl-icon name="arrow-right" />
                </kbd>
                /
                <kbd>l</kbd>
              </td>
              <td>{{ __('Scroll right') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>
                  <gl-icon name="arrow-up" />
                </kbd>
                /
                <kbd>k</kbd>
              </td>
              <td>{{ __('Scroll up') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>
                  <gl-icon name="arrow-down" />
                </kbd>
                /
                <kbd>j</kbd>
              </td>
              <td>{{ __('Scroll down') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>
                  shift
                  <gl-icon name="arrow-up" />
                  / k
                </kbd>
              </td>
              <td>{{ __('Scroll to top') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>
                  shift
                  <gl-icon name="arrow-down" />
                  / j
                </kbd>
              </td>
              <td>{{ __('Scroll to bottom') }}</td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="col-lg-4">
        <table class="shortcut-mappings text-2">
          <tbody>
            <tr>
              <th></th>
              <th>{{ __('Project') }}</th>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>g</kbd>
                <kbd>p</kbd>
              </td>
              <td>{{ __("Go to the project's overview page") }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>g</kbd>
                <kbd>v</kbd>
              </td>
              <td>{{ __("Go to the project's activity feed") }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>g</kbd>
                <kbd>r</kbd>
              </td>
              <td>{{ __('Go to releases') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>g</kbd>
                <kbd>f</kbd>
              </td>
              <td>{{ __('Go to files') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>t</kbd>
              </td>
              <td>{{ __('Go to find file') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>g</kbd>
                <kbd>c</kbd>
              </td>
              <td>{{ __('Go to commits') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>g</kbd>
                <kbd>n</kbd>
              </td>
              <td>{{ __('Go to repository graph') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>g</kbd>
                <kbd>d</kbd>
              </td>
              <td>{{ __('Go to repository charts') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>g</kbd>
                <kbd>i</kbd>
              </td>
              <td>{{ __('Go to issues') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>i</kbd>
              </td>
              <td>{{ __('New issue') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>g</kbd>
                <kbd>b</kbd>
              </td>
              <td>{{ __('Go to issue boards') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>g</kbd>
                <kbd>m</kbd>
              </td>
              <td>{{ __('Go to merge requests') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>g</kbd>
                <kbd>j</kbd>
              </td>
              <td>{{ __('Go to jobs') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>g</kbd>
                <kbd>l</kbd>
              </td>
              <td>{{ __('Go to metrics') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>g</kbd>
                <kbd>e</kbd>
              </td>
              <td>{{ __('Go to environments') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>g</kbd>
                <kbd>k</kbd>
              </td>
              <td>{{ __('Go to kubernetes') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>g</kbd>
                <kbd>s</kbd>
              </td>
              <td>{{ __('Go to snippets') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>g</kbd>
                <kbd>w</kbd>
              </td>
              <td>{{ __('Go to wiki') }}</td>
            </tr>
          </tbody>
          <tbody>
            <tr>
              <th></th>
              <th>{{ __('Project Files') }}</th>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>
                  <gl-icon name="arrow-up" />
                </kbd>
              </td>
              <td>{{ __('Move selection up') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>
                  <gl-icon name="arrow-down" />
                </kbd>
              </td>
              <td>{{ __('Move selection down') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>enter</kbd>
              </td>
              <td>{{ __('Open Selection') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>esc</kbd>
              </td>
              <td>{{ __('Go back (while searching for files)') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>y</kbd>
              </td>
              <td>{{ __('Go to file permalink (while viewing a file)') }}</td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="col-lg-4">
        <table class="shortcut-mappings text-2">
          <tbody>
            <tr>
              <th></th>
              <th>{{ __('Epics, issues, and merge requests') }}</th>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>r</kbd>
              </td>
              <td>{{ __('Comment/Reply (quoting selected text)') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>e</kbd>
              </td>
              <td>{{ __('Edit description') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>l</kbd>
              </td>
              <td>{{ __('Change label') }}</td>
            </tr>
          </tbody>
          <tbody>
            <tr>
              <th></th>
              <th>{{ __('Issues and merge requests') }}</th>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>a</kbd>
              </td>
              <td>{{ __('Change assignee') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>m</kbd>
              </td>
              <td>{{ __('Change milestone') }}</td>
            </tr>
          </tbody>
          <tbody>
            <tr>
              <th></th>
              <th>{{ __('Merge requests') }}</th>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>]</kbd>
                /
                <kbd>j</kbd>
              </td>
              <td>{{ __('Next file in diff') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>[</kbd>
                /
                <kbd>k</kbd>
              </td>
              <td>{{ __('Previous file in diff') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>{{ ctrlCharacter }} p</kbd>
              </td>
              <td>{{ __('Go to file') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>n</kbd>
              </td>
              <td>{{ __('Next unresolved discussion') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>p</kbd>
              </td>
              <td>{{ __('Previous unresolved discussion') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>b</kbd>
              </td>
              <td>{{ __('Copy source branch name') }}</td>
            </tr>
          </tbody>
          <tbody>
            <tr>
              <th></th>
              <th>{{ __('Merge request commits') }}</th>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>c</kbd>
              </td>
              <td>{{ __('Next commit') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>x</kbd>
              </td>
              <td>{{ __('Previous commit') }}</td>
            </tr>
          </tbody>
          <tbody>
            <tr>
              <th></th>
              <th>{{ __('Web IDE') }}</th>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>{{ ctrlCharacter }} p</kbd>
              </td>
              <td>{{ __('Go to file') }}</td>
            </tr>
            <tr>
              <td class="shortcut">
                <kbd>{{ ctrlCharacter }} enter</kbd>
              </td>
              <td>{{ __('Commit (when editing commit message)') }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </gl-modal>
</template>
