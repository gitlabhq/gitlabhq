import $ from 'jquery';
import { isInIssuePage, isInMRPage, isInEpicPage } from './common_utils';

const isVueMRDiscussions = () => isInMRPage() && !$('#diffs').is(':visible');

export const addClassIfElementExists = (element, className) => {
  if (element) {
    element.classList.add(className);
  }
};

export const isInVueNoteablePage = () => isInIssuePage() || isInEpicPage() || isVueMRDiscussions();
