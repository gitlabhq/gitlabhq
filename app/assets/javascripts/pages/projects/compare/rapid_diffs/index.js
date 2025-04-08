import initCompareSelector from '~/projects/compare';
import { createRapidDiffsApp } from '~/rapid_diffs/app';

initCompareSelector();

const app = createRapidDiffsApp();
app.init();
app.reloadDiffs();
