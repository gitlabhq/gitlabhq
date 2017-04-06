/* eslint-disable import/prefer-default-export */

/**
 * Function that allows a number with an X amount of decimals
 * to be formatted in the following fashion:
 * * For 1 digit to the left of the decimal point and X digits to the right of it
 * * * Show 3 digits to the right
 * * For 2 digits to the left of the decimal point and X digits to the right of it
 * * * Show 2 digits to the right
*/
export function formatRelevantDigits(number) {
  let digitsLeft = '';
  let relevantDigits = 0;
  let formattedNumber = '';
  if (!isNaN(Number(number))) {
    digitsLeft = number.split('.')[0];
    switch (digitsLeft.length) {
      case 1:
        relevantDigits = 3;
        break;
      case 2:
        relevantDigits = 2;
        break;
      case 3:
        relevantDigits = 1;
        break;
      default:
        relevantDigits = 4;
        break;
    }
    formattedNumber = Number(number).toFixed(relevantDigits);
  }
  return formattedNumber;
}
