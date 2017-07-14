import ActivityCalendar from './activity_calendar';
import User from './user';

// use legacy exports until embedded javascript is refactored
window.Calendar = ActivityCalendar;
window.gl = window.gl || {};
window.gl.User = User;
