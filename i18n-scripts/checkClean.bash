#!/bin/bash
for i in `ls *\.zh\.*`;
do
	#diff appearances_helper.* && rm -i appearances_helper.zh.rb
	old=${i/.zh/}
	echo " ############### "$old"    #############"
	diff "$old" "$i" >/dev/null && rm -i "$i"
	echo
	echo
done
