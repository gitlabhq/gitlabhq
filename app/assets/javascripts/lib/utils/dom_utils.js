import $ from 'jquery';
import { isInIssuePage, isInMRPage, isInEpicPage, hasVueMRDiscussionsCookie } from './common_utils';

const isVueMRDiscussions = () => isInMRPage() && hasVueMRDiscussionsCookie() && !$('#diffs').is(':visible');

export const addClassIfElementExists = (element, className) => {
  if (element) {
    element.classList.add(className);
  }
};

export const isInVueNoteablePage = () => isInIssuePage() || isInEpicPage() || isVueMRDiscussions();
