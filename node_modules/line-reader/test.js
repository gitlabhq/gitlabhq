// var file = './test/data/multibyte_file.txt';
var file = './test/data/three_line_file.txt';
// var file = './test/data/mac_os_9_file.txt';
// var file = './test/data/separator_file.txt';

var util = require('util');

// var lineReader = require('readline').createInterface({
  // input: require('fs').createReadStream(file)
// });

// lineReader.on('line', function (line) {
  // console.log('Line from file:', util.inspect(line));
// });



var fs = require('fs');

// var readStream = fs.createReadStream(file);
// // var hash = crypto.createHash('sha1');

// readStream
  // .on('readable', function () {
    // var chunk;
    // while (null !== (chunk = readStream.read())) {
      // console.log(chunk.length);
    // }
  // })
  // .on('end', function () {
    // console.log('done!');
  // });



// var readable = process.stdin;
//

// var readable = fs.createReadStream(file);
// readable.pause();

// console.log(readable.isPaused());

// readable.on('readable', () => {
  // var chunk;
  // console.log('called');
  // while (null !== (chunk = readable.read(4))) {
    // console.log('got %d bytes of data: %s', chunk.length, util.inspect(chunk.toString()));
  // }
// });

// readable.on('end', () => {
  // console.log('done!');
// });
//
//

var lineReader = require('./lib/line_reader');
var readStream = fs.createReadStream('development.log', { start: 0, end: 10000 });
lineReader.eachLine(readStream, (line) => console.log(line));



// var lineReader = require('./lib/line_reader'),
    // Promise = require('bluebird');

// var eachLine = Promise.promisify(lineReader.eachLine);
// eachLine(process.stdin, function(line) {
  // console.log(line);
// }).then(function() {
  // console.log('DONE');
// }).catch(function(err) {
  // console.error(err);
// });


// const readline = require('readline');

// const rl = readline.createInterface({
  // input: process.stdin,
  // output: process.stdout
// });

// rl.question('What do you think of Node.js? ', (answer) => {
  // TODO: Log the answer in a database
  // console.log('Thank you for your valuable feedback:', answer);

  // rl.close();
// });
